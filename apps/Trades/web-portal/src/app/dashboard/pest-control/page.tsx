'use client';

import { useState } from 'react';
import { useTranslation } from '@/lib/translations';
import {
  useTreatmentLogs,
  useBaitStations,
  useWdiReports,
  SERVICE_TYPE_LABELS,
  TREATMENT_TYPE_LABELS,
  type TreatmentLog,
  type PestServiceType,
} from '@/lib/hooks/use-pest-control';
import { SearchInput } from '@/components/ui/input';

const SERVICE_COLORS: Record<string, string> = {
  general_pest: 'bg-green-500/15 text-green-400',
  termite: 'bg-red-500/15 text-red-400',
  bed_bug: 'bg-purple-500/15 text-purple-400',
  fumigation: 'bg-orange-500/15 text-orange-400',
  rodent: 'bg-yellow-500/15 text-yellow-400',
  wildlife: 'bg-amber-500/15 text-amber-400',
};

function formatDate(iso: string | null): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export default function PestControlPage() {
  const { t } = useTranslation();
  const { logs, loading: logsLoading } = useTreatmentLogs();
  const { stations } = useBaitStations();
  const { reports } = useWdiReports();
  const [searchQuery, setSearchQuery] = useState('');
  const [tab, setTab] = useState<'treatments' | 'stations' | 'wdi'>('treatments');

  const filteredLogs = logs.filter((l) => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      (l.chemical_name ?? '').toLowerCase().includes(q) ||
      (l.service_type ?? '').toLowerCase().includes(q) ||
      (l.notes ?? '').toLowerCase().includes(q) ||
      l.target_pests.some((p) => p.toLowerCase().includes(q))
    );
  });

  // Stats
  const totalTreatments = logs.length;
  const activeStations = stations.filter((s) => s.activity_level !== 'none').length;
  const pendingWdi = reports.filter((r) => r.report_status === 'draft' || r.report_status === 'submitted').length;
  const upcoming = logs.filter((l) => l.next_service_date && new Date(l.next_service_date) > new Date()).length;

  if (logsLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">{t('pestControl.title')}</h1>
        <p className="text-sm text-zinc-400 mt-1">Treatment logs, bait stations, WDI/NPMA-33 reports</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">Treatments</p>
          <p className="text-2xl font-bold text-white">{totalTreatments}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">Active Stations</p>
          <p className="text-2xl font-bold text-yellow-400">{activeStations}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">Pending WDI</p>
          <p className="text-2xl font-bold text-purple-400">{pendingWdi}</p>
        </div>
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
          <p className="text-xs text-zinc-500 mb-1">Upcoming Services</p>
          <p className="text-2xl font-bold text-blue-400">{upcoming}</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-3">
        {(['treatments', 'stations', 'wdi'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2 rounded-lg text-sm font-medium border transition-colors ${
              tab === t ? 'bg-white/10 text-white border-white/20' : 'text-zinc-400 border-zinc-700 hover:border-zinc-600'
            }`}
          >
            {t === 'treatments' ? 'Treatments' : t === 'stations' ? 'Bait Stations' : 'WDI Reports'}
          </button>
        ))}
        <div className="flex-1" />
        {tab === 'treatments' && (
          <div className="max-w-xs">
            <SearchInput placeholder="Search treatments..." value={searchQuery} onChange={(v) => setSearchQuery(v)} />
          </div>
        )}
      </div>

      {/* Content */}
      {tab === 'treatments' && (
        <div className="space-y-3">
          {filteredLogs.length === 0 ? (
            <div className="text-center py-12 text-zinc-500"><p>{t('pestControl.noRecords')}</p></div>
          ) : (
            filteredLogs.map((l) => (
              <div key={l.id} className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded ${SERVICE_COLORS[l.service_type] ?? 'bg-zinc-700 text-zinc-300'}`}>
                      {SERVICE_TYPE_LABELS[l.service_type] ?? l.service_type}
                    </span>
                    <span className="text-xs text-zinc-500">
                      {TREATMENT_TYPE_LABELS[l.treatment_type] ?? l.treatment_type}
                    </span>
                  </div>
                  <span className="text-xs text-zinc-500">{formatDate(l.created_at)}</span>
                </div>
                {l.chemical_name && (
                  <p className="text-sm text-white font-medium">{l.chemical_name}</p>
                )}
                <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                  {l.epa_registration_number && <span>EPA #{l.epa_registration_number}</span>}
                  {l.target_area_sqft && <span>{l.target_area_sqft} sqft</span>}
                  {l.re_entry_time_hours && <span>Re-entry: {l.re_entry_time_hours}h</span>}
                </div>
                {l.next_service_date && (
                  <div className="mt-2 flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-400" />
                    <span className="text-xs text-blue-400">Next: {formatDate(l.next_service_date)}</span>
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      )}

      {tab === 'stations' && (
        <div className="space-y-3">
          {stations.length === 0 ? (
            <div className="text-center py-12 text-zinc-500"><p>No bait stations</p></div>
          ) : (
            stations.map((s) => {
              const color = s.activity_level === 'critical' ? 'text-red-400' :
                           s.activity_level === 'high' ? 'text-orange-400' :
                           s.activity_level === 'moderate' ? 'text-yellow-400' :
                           s.activity_level === 'low' ? 'text-blue-400' : 'text-green-400';
              return (
                <div key={s.id} className="bg-zinc-900 border border-zinc-800 rounded-xl p-4 flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg bg-zinc-800 flex items-center justify-center text-sm font-bold text-zinc-300">
                    #{s.station_number}
                  </div>
                  <div className="flex-1">
                    <p className="text-sm text-white font-medium capitalize">{s.station_type.replace('_', ' ')} Station</p>
                    <p className="text-xs text-zinc-500">{s.location_description ?? 'No location'} • {s.placement_zone ?? 'Unknown zone'}</p>
                  </div>
                  <div className="text-right">
                    <p className={`text-xs font-semibold capitalize ${color}`}>{s.activity_level}</p>
                    <p className="text-[10px] text-zinc-600">Serviced: {formatDate(s.last_serviced_at)}</p>
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}

      {tab === 'wdi' && (
        <div className="space-y-3">
          {reports.length === 0 ? (
            <div className="text-center py-12 text-zinc-500"><p>No WDI reports</p></div>
          ) : (
            reports.map((r) => (
              <div key={r.id} className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold px-2 py-0.5 rounded bg-purple-500/15 text-purple-400">
                      {r.report_type === 'npma_33' ? 'NPMA-33' : r.report_type.toUpperCase()}
                    </span>
                    <span className={`text-xs font-medium px-2 py-0.5 rounded ${
                      r.report_status === 'accepted' ? 'bg-green-500/15 text-green-400' :
                      r.report_status === 'rejected' ? 'bg-red-500/15 text-red-400' :
                      'bg-zinc-700 text-zinc-300'
                    }`}>
                      {r.report_status.charAt(0).toUpperCase() + r.report_status.slice(1)}
                    </span>
                  </div>
                  <span className="text-xs text-zinc-500">{formatDate(r.inspection_date)}</span>
                </div>
                <p className="text-sm text-white font-medium">
                  {r.property_address ?? 'Address pending'} • {r.inspector_name ?? 'Inspector TBD'}
                </p>
                <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                  <span className={r.infestation_found ? 'text-red-400 font-semibold' : ''}>
                    Infestation: {r.infestation_found ? 'YES' : 'No'}
                  </span>
                  <span className={r.damage_found ? 'text-orange-400 font-semibold' : ''}>
                    Damage: {r.damage_found ? 'YES' : 'No'}
                  </span>
                  {r.insects_identified.length > 0 && (
                    <span>Identified: {r.insects_identified.join(', ')}</span>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}
