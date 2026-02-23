'use client';

import { useState } from 'react';
import {
  Plus,
  Droplets,
  Activity,
  Target,
  BarChart3,
  CheckCircle,
  AlertTriangle,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDateTime, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useRestorationTools } from '@/lib/hooks/use-restoration-tools';
import type { MoistureReadingWithJob } from '@/lib/hooks/use-restoration-tools';

const materialLabels: Record<string, string> = {
  drywall: 'Drywall',
  wood: 'Wood',
  concrete: 'Concrete',
  carpet: 'Carpet',
  pad: 'Pad',
  insulation: 'Insulation',
  subfloor: 'Subfloor',
  hardwood: 'Hardwood',
  laminate: 'Laminate',
  tile_backer: 'Tile Backer',
  other: 'Other',
};

const materialOptions = [
  { value: 'all', label: 'All Materials' },
  ...Object.entries(materialLabels).map(([value, label]) => ({ value, label })),
];

const dryOptions = [
  { value: 'all', label: 'All Status' },
  { value: 'dry', label: 'Dry' },
  { value: 'wet', label: 'Wet' },
];

function getReadingColor(reading: MoistureReadingWithJob): string {
  if (reading.targetValue == null) return 'text-zinc-300';
  if (reading.readingValue <= reading.targetValue) return 'text-emerald-400';
  const threshold = reading.targetValue * 1.2;
  if (reading.readingValue <= threshold) return 'text-amber-400';
  return 'text-red-400';
}

function getReadingBg(reading: MoistureReadingWithJob): string {
  if (reading.targetValue == null) return '';
  if (reading.readingValue <= reading.targetValue) return 'bg-emerald-900/10';
  const threshold = reading.targetValue * 1.2;
  if (reading.readingValue <= threshold) return 'bg-amber-900/10';
  return 'bg-red-900/10';
}

export default function MoistureReadingsPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [materialFilter, setMaterialFilter] = useState('all');
  const [dryFilter, setDryFilter] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const { readings, stats, loading } = useRestorationTools();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-56 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div><div className="skeleton h-5 w-16 rounded-full" /></div>)}
        </div>
      </div>
    );
  }

  const filtered = readings.filter((r) => {
    const matchesSearch =
      r.jobName.toLowerCase().includes(search.toLowerCase()) ||
      r.areaName.toLowerCase().includes(search.toLowerCase());
    const matchesMaterial = materialFilter === 'all' || r.materialType === materialFilter;
    const matchesDry =
      dryFilter === 'all' ||
      (dryFilter === 'dry' && r.isDry) ||
      (dryFilter === 'wet' && !r.isDry);
    return matchesSearch && matchesMaterial && matchesDry;
  });

  // Stats
  const uniqueJobs = new Set(readings.map((r) => r.jobId)).size;
  const atTarget = readings.filter((r) => r.targetValue != null && r.readingValue <= r.targetValue).length;
  const avgReading = readings.length > 0
    ? (readings.reduce((sum, r) => sum + r.readingValue, 0) / readings.length).toFixed(1)
    : '0.0';

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('moistureReadings.title')}</h1>
          <p className="text-muted mt-1">Track and monitor moisture levels across restoration jobs</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          Add Reading
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Droplets size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats.totalReadings}</p>
                <p className="text-sm text-muted">Total Readings</p>
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
                <p className="text-sm text-muted">{t('dashboard.activeJobs')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Target size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{atTarget}</p>
                <p className="text-sm text-muted">Areas at Target</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <BarChart3 size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{avgReading}</p>
                <p className="text-sm text-muted">Avg Reading</p>
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
          placeholder="Search by job or area..."
          className="sm:w-80"
        />
        <Select
          options={materialOptions}
          value={materialFilter}
          onChange={(e) => setMaterialFilter(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={dryOptions}
          value={dryFilter}
          onChange={(e) => setDryFilter(e.target.value)}
          className="sm:w-40"
        />
      </div>

      {/* Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Date/Time</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.job')}</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.area')}</th>
                <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Material</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Reading</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.target')}</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase tracking-wider">Dry?</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((r) => (
                <tr key={r.id} className={cn('hover:bg-surface-hover transition-colors', getReadingBg(r))}>
                  <td className="px-4 py-3 text-main whitespace-nowrap">{formatDateTime(r.recordedAt)}</td>
                  <td className="px-4 py-3 text-main font-medium truncate max-w-[200px]">{r.jobName || 'Unknown Job'}</td>
                  <td className="px-4 py-3 text-main">
                    <div>{r.areaName}</div>
                    {r.floorLevel && <div className="text-xs text-muted">{r.floorLevel}</div>}
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant="secondary">{materialLabels[r.materialType] || r.materialType}</Badge>
                  </td>
                  <td className={cn('px-4 py-3 text-right font-mono font-medium', getReadingColor(r))}>
                    {r.readingValue}
                    <span className="text-xs text-muted ml-1">
                      {r.readingUnit === 'percent' ? '%' : r.readingUnit}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-muted">
                    {r.targetValue != null ? (
                      <>
                        {r.targetValue}
                        <span className="text-xs ml-1">
                          {r.readingUnit === 'percent' ? '%' : r.readingUnit}
                        </span>
                      </>
                    ) : (
                      <span className="text-zinc-500">--</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {r.isDry ? (
                      <CheckCircle size={16} className="text-emerald-500 mx-auto" />
                    ) : (
                      <AlertTriangle size={16} className="text-amber-500 mx-auto" />
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {filtered.length === 0 && (
          <CardContent className="p-12 text-center">
            <Droplets size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('moistureReadings.noRecords')}</h3>
            <p className="text-muted mb-4">Start logging moisture readings to track drying progress across restoration jobs.</p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />Add Reading
            </Button>
          </CardContent>
        )}
      </Card>

      {showAddModal && <AddReadingModal onClose={() => setShowAddModal(false)} />}
    </div>
  );
}

function AddReadingModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Moisture Reading</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Area Name *" placeholder="Living Room - North Wall" />
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Material Type *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                {Object.entries(materialLabels).map(([value, label]) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>
            <Input label="Floor Level" placeholder="1st Floor" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Reading Value *" type="number" placeholder="0.0" />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.unit')}</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="percent">Percent (%)</option>
                <option value="relative">Relative</option>
                <option value="wme">WME</option>
                <option value="grains">Grains</option>
              </select>
            </div>
          </div>
          <Input label="Target Value" type="number" placeholder="Optional target" />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Meter Type" placeholder="Pin / Pinless" />
            <Input label="Meter Model" placeholder="Delmhorst BD-2100" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Ambient Temp (F)" type="number" placeholder="72" />
            <Input label="Ambient Humidity (%)" type="number" placeholder="55" />
          </div>
          <div className="flex items-center gap-2 pt-2">
            <input type="checkbox" id="isDry" className="rounded border-main bg-main" />
            <label htmlFor="isDry" className="text-sm text-main">Mark as Dry</label>
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1"><Plus size={16} />Save Reading</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
