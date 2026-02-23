'use client';

import { useState } from 'react';
import { useTranslation } from '@/lib/translations';
import { useGarageDoorLogs, GARAGE_DOOR_SERVICE_LABELS, DOOR_TYPE_LABELS } from '@/lib/hooks/use-garage-door';
import { SearchInput } from '@/components/ui/input';

const SERVICE_COLORS: Record<string, string> = {
  spring_replacement: 'bg-orange-500/15 text-orange-400',
  opener_repair: 'bg-yellow-500/15 text-yellow-400',
  opener_install: 'bg-green-500/15 text-green-400',
  full_door_install: 'bg-blue-500/15 text-blue-400',
  safety_sensor: 'bg-red-500/15 text-red-400',
  annual_maintenance: 'bg-purple-500/15 text-purple-400',
};

function statusBadge(status: string | null) {
  if (!status) return null;
  const color = status === 'pass' ? 'bg-green-500/15 text-green-400' : status === 'fail' ? 'bg-red-500/15 text-red-400' : 'bg-zinc-700 text-zinc-400';
  return <span className={`text-[10px] font-semibold px-1.5 py-0.5 rounded ${color}`}>{status}</span>;
}

export default function GarageDoorPage() {
  const { t, formatDate } = useTranslation();
  const { logs, loading } = useGarageDoorLogs();
  const [search, setSearch] = useState('');

  const filtered = logs.filter((l) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      (l.opener_brand ?? '').toLowerCase().includes(q) ||
      (l.service_type ?? '').toLowerCase().includes(q) ||
      (l.diagnosis ?? '').toLowerCase().includes(q) ||
      (l.door_type ?? '').toLowerCase().includes(q)
    );
  });

  const springJobs = logs.filter((l) => l.service_type === 'spring_replacement').length;
  const failedSensors = logs.filter((l) => l.safety_sensor_status === 'fail').length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">{t('garageDoor.title')}</h1>
          <p className="text-sm text-zinc-400 mt-1">Service logs, spring specs, safety tests</p>
        </div>
        <div className="max-w-xs">
          <SearchInput placeholder="Search services..." value={search} onChange={(v) => setSearch(v)} />
        </div>
      </div>

      <div className="grid grid-cols-4 gap-4">
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">{t('common.totalServices')}</p>
          <p className="text-2xl font-bold text-white">{logs.length}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">Spring Jobs</p>
          <p className="text-2xl font-bold text-orange-400">{springJobs}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">Failed Sensors</p>
          <p className="text-2xl font-bold text-red-400">{failedSensors}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">{t('common.revenue')}</p>
          <p className="text-2xl font-bold text-green-400">
            ${logs.reduce((s, l) => s + (l.total_cost ?? 0), 0).toLocaleString()}
          </p>
        </div>
      </div>

      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-zinc-500"><p>{t('garageDoor.noRecords')}</p></div>
        ) : (
          filtered.map((l) => (
            <div key={l.id} className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded ${SERVICE_COLORS[l.service_type] ?? 'bg-zinc-700 text-zinc-300'}`}>
                    {GARAGE_DOOR_SERVICE_LABELS[l.service_type] ?? l.service_type}
                  </span>
                  <span className="text-xs text-zinc-500">{DOOR_TYPE_LABELS[l.door_type] ?? l.door_type}</span>
                </div>
                <span className="text-xs text-zinc-500">{formatDate(l.created_at)}</span>
              </div>
              <div className="flex items-center gap-3 text-xs text-zinc-500">
                {l.door_width_inches && l.door_height_inches && (
                  <span>{Math.round(l.door_width_inches / 12)}&apos; x {Math.round(l.door_height_inches / 12)}&apos;</span>
                )}
                {l.opener_brand && <span>{l.opener_brand}</span>}
                {l.spring_type && <span className="capitalize">{l.spring_type.replace('_', ' ')} spring</span>}
              </div>
              <div className="flex items-center gap-2 mt-2">
                {l.safety_sensor_status && (
                  <div className="flex items-center gap-1">
                    <span className="text-[10px] text-zinc-500">Sensors:</span>
                    {statusBadge(l.safety_sensor_status)}
                  </div>
                )}
                {l.balance_test_result && (
                  <div className="flex items-center gap-1">
                    <span className="text-[10px] text-zinc-500">Balance:</span>
                    {statusBadge(l.balance_test_result)}
                  </div>
                )}
              </div>
              {l.diagnosis && <p className="text-xs text-zinc-400 mt-1">{l.diagnosis}</p>}
              {l.total_cost && <p className="text-sm font-bold text-white mt-1">${Number(l.total_cost).toLocaleString()}</p>}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
