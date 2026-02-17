'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

interface ServiceRecord {
  [key: string]: unknown;
  id: string;
  trade: string;
  service_type: string;
  diagnosis: string | null;
  work_performed: string | null;
  total_cost: number | null;
  created_at: string;
  brand?: string;
  error_code?: string;
  repair_vs_replace?: string;
  warranty_status?: string;
}

const TRADE_LABELS: Record<string, string> = { locksmith: 'Locksmith', garage_door: 'Garage Door', appliance: 'Appliance Repair' };

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
}

export default function ServiceHistoryPage() {
  const supabase = getSupabase();
  const [records, setRecords] = useState<ServiceRecord[]>([]);
  const [loading, setLoading] = useState(true);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      const [lockRes, garageRes, appRes] = await Promise.all([
        supabase.from('locksmith_service_logs').select('id, service_type, diagnosis, work_performed, total_cost, created_at').is('deleted_at', null).order('created_at', { ascending: false }),
        supabase.from('garage_door_service_logs').select('id, service_type, diagnosis, work_performed, total_cost, created_at').is('deleted_at', null).order('created_at', { ascending: false }),
        supabase.from('appliance_service_logs').select('id, appliance_type, diagnosis, work_performed, total_cost, created_at, brand, error_code, repair_vs_replace, warranty_status').is('deleted_at', null).order('created_at', { ascending: false }),
      ]);

      const combined: ServiceRecord[] = [
        ...((lockRes.data ?? []) as ServiceRecord[]).map((r) => ({ ...r, trade: 'locksmith' })),
        ...((garageRes.data ?? []) as ServiceRecord[]).map((r) => ({ ...r, trade: 'garage_door' })),
        ...((appRes.data ?? []) as ServiceRecord[]).map((r) => ({ ...r, trade: 'appliance', service_type: (r as Record<string, unknown>).appliance_type as string ?? '' })),
      ].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

      setRecords(combined);
    } catch {
      // Degrade silently
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => { fetch(); }, [fetch]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Service History</h1>
        <p className="text-sm text-gray-500 mt-1">Locksmith, garage door, and appliance repair records for your property</p>
      </div>

      {records.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <p className="text-gray-400 text-sm">No service records on file</p>
        </div>
      ) : (
        <div className="space-y-3">
          {records.map((r) => (
            <div key={`${r.trade}-${r.id}`} className="bg-white rounded-xl border border-gray-200 p-4">
              <div className="flex items-center justify-between mb-2">
                <span className={`text-xs font-semibold px-2 py-0.5 rounded ${
                  r.trade === 'locksmith' ? 'bg-green-100 text-green-700' :
                  r.trade === 'garage_door' ? 'bg-orange-100 text-orange-700' :
                  'bg-purple-100 text-purple-700'
                }`}>
                  {TRADE_LABELS[r.trade] ?? r.trade}
                </span>
                <span className="text-xs text-gray-400">{formatDate(r.created_at)}</span>
              </div>
              <p className="text-sm font-medium text-gray-900 capitalize">{(r.service_type ?? '').replace(/_/g, ' ')}</p>
              {r.diagnosis && <p className="text-sm text-gray-600 mt-1">{r.diagnosis}</p>}
              {r.work_performed && <p className="text-sm text-gray-500 mt-1">{r.work_performed}</p>}
              <div className="flex items-center gap-3 mt-2 text-xs text-gray-500">
                {r.brand && <span>{r.brand}</span>}
                {r.error_code && <span className="text-red-600">Error: {r.error_code}</span>}
                {r.warranty_status && r.warranty_status !== 'unknown' && (
                  <span className={r.warranty_status === 'in_warranty' || r.warranty_status === 'extended_warranty' ? 'text-green-600 font-medium' : ''}>
                    {r.warranty_status.replace(/_/g, ' ')}
                  </span>
                )}
                {r.total_cost && <span className="font-semibold text-gray-900">${Number(r.total_cost).toLocaleString()}</span>}
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
        <h3 className="text-sm font-semibold text-blue-700 mb-1">Need Service?</h3>
        <p className="text-xs text-blue-600 leading-relaxed">
          Contact your service provider to schedule locksmith, garage door, or appliance repair appointments.
          All work performed by licensed and insured technicians.
        </p>
      </div>
    </div>
  );
}
