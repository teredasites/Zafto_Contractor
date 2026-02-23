'use client';

import { useState } from 'react';
import { useTranslation } from '@/lib/translations';
import { useLocksmithLogs, LOCKSMITH_SERVICE_LABELS, LOCK_TYPE_LABELS } from '@/lib/hooks/use-locksmith';
import { SearchInput } from '@/components/ui/input';

const SERVICE_COLORS: Record<string, string> = {
  rekey: 'bg-green-500/15 text-green-400', lockout: 'bg-red-500/15 text-red-400',
  automotive_lockout: 'bg-blue-500/15 text-blue-400', transponder_key: 'bg-blue-500/15 text-blue-400',
  master_key: 'bg-purple-500/15 text-purple-400', safe: 'bg-yellow-500/15 text-yellow-400',
  access_control: 'bg-cyan-500/15 text-cyan-400',
};

export default function LocksmithPage() {
  const { t, formatDate } = useTranslation();
  const { logs, loading } = useLocksmithLogs();
  const [search, setSearch] = useState('');

  const filtered = logs.filter((l) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      (l.lock_brand ?? '').toLowerCase().includes(q) ||
      (l.service_type ?? '').toLowerCase().includes(q) ||
      (l.diagnosis ?? '').toLowerCase().includes(q) ||
      (l.vehicle_make ?? '').toLowerCase().includes(q)
    );
  });

  const automotiveCount = logs.filter((l) => l.service_type === 'automotive_lockout' || l.service_type === 'transponder_key').length;
  const totalRevenue = logs.reduce((sum, l) => sum + (l.total_cost ?? 0), 0);

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
          <h1 className="text-2xl font-bold text-white">{t('locksmith.title')}</h1>
          <p className="text-sm text-zinc-400 mt-1">Service logs, master key systems, automotive</p>
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
          <p className="text-xs text-zinc-500 mb-1">{t('common.automotive')}</p>
          <p className="text-2xl font-bold text-blue-400">{automotiveCount}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">{t('common.revenue')}</p>
          <p className="text-2xl font-bold text-green-400">${totalRevenue.toLocaleString()}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">{t('common.thisMonth')}</p>
          <p className="text-2xl font-bold text-purple-400">
            {logs.filter((l) => new Date(l.created_at).getMonth() === new Date().getMonth()).length}
          </p>
        </div>
      </div>

      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-zinc-500"><p>{t('locksmith.noRecords')}</p></div>
        ) : (
          filtered.map((l) => (
            <div key={l.id} className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded ${SERVICE_COLORS[l.service_type] ?? 'bg-zinc-700 text-zinc-300'}`}>
                    {LOCKSMITH_SERVICE_LABELS[l.service_type] ?? l.service_type}
                  </span>
                  {l.lock_type && (
                    <span className="text-xs text-zinc-500">{LOCK_TYPE_LABELS[l.lock_type] ?? l.lock_type}</span>
                  )}
                </div>
                <span className="text-xs text-zinc-500">{formatDate(l.created_at)}</span>
              </div>
              {l.lock_brand && <p className="text-sm text-white font-medium">{l.lock_brand}</p>}
              {(l.service_type === 'automotive_lockout' || l.service_type === 'transponder_key') && l.vehicle_make && (
                <p className="text-sm text-blue-400">{[l.vehicle_year, l.vehicle_make, l.vehicle_model].filter(Boolean).join(' ')}</p>
              )}
              <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                {l.pins && <span>{l.pins} pins</span>}
                {l.keyway && <span>Keyway: {l.keyway}</span>}
                {l.bitting_code && <span>Bitting: {l.bitting_code}</span>}
              </div>
              {l.diagnosis && <p className="text-xs text-zinc-400 mt-1">{l.diagnosis}</p>}
              {l.total_cost && (
                <p className="text-sm font-bold text-white mt-1">${Number(l.total_cost).toLocaleString()}</p>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
