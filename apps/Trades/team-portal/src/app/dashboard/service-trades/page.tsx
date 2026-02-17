'use client';

import { useEffect, useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

interface ServiceLog {
  id: string;
  trade: 'locksmith' | 'garage_door' | 'appliance';
  service_type: string;
  diagnosis: string | null;
  total_cost: number | null;
  created_at: string;
  // Trade-specific
  lock_brand?: string;
  door_type?: string;
  appliance_type?: string;
  brand?: string;
  error_code?: string;
  repair_vs_replace?: string;
}

const TRADE_LABELS: Record<string, string> = { locksmith: 'Locksmith', garage_door: 'Garage Door', appliance: 'Appliance' };
const TRADE_COLORS: Record<string, string> = {
  locksmith: 'bg-green-100 text-green-700',
  garage_door: 'bg-orange-100 text-orange-700',
  appliance: 'bg-purple-100 text-purple-700',
};

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export default function ServiceTradesPage() {
  const supabase = createClient();
  const [logs, setLogs] = useState<ServiceLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'all' | 'locksmith' | 'garage_door' | 'appliance'>('all');

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      const [lockRes, garageRes, appRes] = await Promise.all([
        supabase.from('locksmith_service_logs').select('id, service_type, diagnosis, total_cost, created_at, lock_brand').is('deleted_at', null).order('created_at', { ascending: false }).limit(50),
        supabase.from('garage_door_service_logs').select('id, service_type, diagnosis, total_cost, created_at, door_type').is('deleted_at', null).order('created_at', { ascending: false }).limit(50),
        supabase.from('appliance_service_logs').select('id, appliance_type, diagnosis, total_cost, created_at, brand, error_code, repair_vs_replace').is('deleted_at', null).order('created_at', { ascending: false }).limit(50),
      ]);

      const combined: ServiceLog[] = [
        ...((lockRes.data ?? []) as ServiceLog[]).map((l) => ({ ...l, trade: 'locksmith' as const })),
        ...((garageRes.data ?? []) as ServiceLog[]).map((l) => ({ ...l, trade: 'garage_door' as const, service_type: l.service_type ?? l.door_type ?? '' })),
        ...((appRes.data ?? []) as ServiceLog[]).map((l) => ({ ...l, trade: 'appliance' as const, service_type: l.appliance_type ?? '' })),
      ].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

      setLogs(combined);
    } catch {
      // Degrade silently for team portal
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => { fetch(); }, [fetch]);

  const filtered = tab === 'all' ? logs : logs.filter((l) => l.trade === tab);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Service Trades</h1>
        <p className="text-sm text-gray-500 mt-1">Locksmith, garage door, and appliance repair service logs</p>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {(['locksmith', 'garage_door', 'appliance'] as const).map((t) => (
          <div key={t} className="bg-white rounded-xl border border-gray-200 p-4 text-center">
            <p className="text-2xl font-bold text-gray-900">{logs.filter((l) => l.trade === t).length}</p>
            <p className="text-xs text-gray-500">{TRADE_LABELS[t]}</p>
          </div>
        ))}
      </div>

      <div className="flex gap-2">
        {(['all', 'locksmith', 'garage_door', 'appliance'] as const).map((t) => (
          <button key={t} onClick={() => setTab(t)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium border ${
              tab === t ? 'bg-gray-900 text-white border-gray-900' : 'text-gray-500 border-gray-200'
            }`}>
            {t === 'all' ? 'All' : TRADE_LABELS[t]}
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <div className="text-center py-12 text-gray-400"><p>No service logs found</p></div>
      ) : (
        <div className="space-y-3">
          {filtered.map((l) => (
            <div key={`${l.trade}-${l.id}`} className="bg-white rounded-xl border border-gray-200 p-4">
              <div className="flex items-center justify-between mb-1">
                <div className="flex items-center gap-2">
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded ${TRADE_COLORS[l.trade]}`}>
                    {TRADE_LABELS[l.trade]}
                  </span>
                  <span className="text-xs text-gray-500 capitalize">{(l.service_type ?? '').replace(/_/g, ' ')}</span>
                </div>
                <span className="text-xs text-gray-400">{formatDate(l.created_at)}</span>
              </div>
              {l.diagnosis && <p className="text-sm text-gray-700">{l.diagnosis}</p>}
              <div className="flex items-center gap-3 mt-1 text-xs text-gray-500">
                {l.lock_brand && <span>{l.lock_brand}</span>}
                {l.brand && <span>{l.brand}</span>}
                {l.error_code && <span className="text-red-600">Error: {l.error_code}</span>}
                {l.repair_vs_replace && <span className="capitalize">{l.repair_vs_replace.replace(/_/g, ' ')}</span>}
                {l.total_cost && <span className="font-semibold text-gray-900">${Number(l.total_cost).toLocaleString()}</span>}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
