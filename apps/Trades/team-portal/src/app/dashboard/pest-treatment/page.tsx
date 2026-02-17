'use client';

import { useEffect, useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

interface TreatmentLog {
  id: string;
  service_type: string;
  treatment_type: string;
  chemical_name: string | null;
  epa_registration_number: string | null;
  target_area_sqft: number | null;
  re_entry_time_hours: number | null;
  next_service_date: string | null;
  applicator_name: string | null;
  created_at: string;
}

const TYPE_LABELS: Record<string, string> = {
  general_pest: 'General Pest', termite: 'Termite', mosquito: 'Mosquito', bed_bug: 'Bed Bug',
  wildlife: 'Wildlife', fumigation: 'Fumigation', rodent: 'Rodent', ant: 'Ant',
  cockroach: 'Cockroach', tick_flea: 'Tick/Flea', spider: 'Spider', wasp_bee: 'Wasp/Bee',
};

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export default function PestTreatmentPage() {
  const supabase = createClient();
  const [logs, setLogs] = useState<TreatmentLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      const { data, error: err } = await supabase
        .from('treatment_logs')
        .select('id, service_type, treatment_type, chemical_name, epa_registration_number, target_area_sqft, re_entry_time_hours, next_service_date, applicator_name, created_at')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setLogs((data ?? []) as TreatmentLog[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
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

  if (error) {
    return <div className="text-center py-12 text-red-600">{error}</div>;
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Pest Treatment Log</h1>
        <p className="text-sm text-gray-500 mt-1">Chemical applications, service records, upcoming treatments</p>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold text-gray-900">{logs.length}</p>
          <p className="text-xs text-gray-500">Total Treatments</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold text-blue-600">
            {logs.filter((l) => l.next_service_date).length}
          </p>
          <p className="text-xs text-gray-500">Recurring</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold text-green-600">
            {logs.filter((l) => l.chemical_name).length}
          </p>
          <p className="text-xs text-gray-500">Chemical Apps</p>
        </div>
      </div>

      {logs.length === 0 ? (
        <div className="text-center py-12 text-gray-400"><p>No treatments logged</p></div>
      ) : (
        <div className="space-y-3">
          {logs.map((l) => (
            <div key={l.id} className="bg-white rounded-xl border border-gray-200 p-4">
              <div className="flex items-center justify-between mb-1">
                <span className="text-xs font-semibold px-2 py-0.5 rounded bg-green-100 text-green-700">
                  {TYPE_LABELS[l.service_type] ?? l.service_type}
                </span>
                <span className="text-xs text-gray-400">{formatDate(l.created_at)}</span>
              </div>
              {l.chemical_name && (
                <p className="text-sm font-medium text-gray-900">{l.chemical_name}</p>
              )}
              <div className="flex gap-3 mt-1 text-xs text-gray-500">
                <span className="capitalize">{l.treatment_type.replace('_', ' ')}</span>
                {l.epa_registration_number && <span>EPA #{l.epa_registration_number}</span>}
                {l.target_area_sqft && <span>{l.target_area_sqft} sqft</span>}
                {l.re_entry_time_hours && <span>Re-entry: {l.re_entry_time_hours}h</span>}
              </div>
              {l.next_service_date && (
                <p className="text-xs text-blue-600 mt-1">Next service: {formatDate(l.next_service_date)}</p>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
